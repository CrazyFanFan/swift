//===--- AvailabilityConstraint.h - Swift Availability Constraints ------*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// This file defines the AvailabilityConstraint class.
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_AST_AVAILABILITY_CONSTRAINT_H
#define SWIFT_AST_AVAILABILITY_CONSTRAINT_H

#include "swift/AST/Attr.h"
#include "swift/AST/AvailabilityDomain.h"
#include "swift/AST/AvailabilityRange.h"
#include "swift/AST/PlatformKind.h"
#include "swift/Basic/LLVM.h"

namespace swift {

class ASTContext;
class AvailabilityContext;
class Decl;

/// Represents the reason a declaration could be considered unavailable in a
/// certain context.
class AvailabilityConstraint {
public:
  enum class Kind {
    /// The declaration is referenced in a context in which it is generally
    /// unavailable. For example, a reference to a declaration that is
    /// unavailable on macOS from a context that may execute on macOS has this
    /// constraint.
    AlwaysUnavailable,

    /// The declaration is referenced in a context in which it is considered
    /// obsolete. For example, a reference to a declaration that is obsolete in
    /// macOS 13 from a context that may execute on macOS 13 or later has this
    /// constraint.
    Obsoleted,

    /// The declaration is only available in a different version. For example,
    /// the declaration might only be introduced in the Swift 6 language mode
    /// while the module is being compiled in the Swift 5 language mode.
    RequiresVersion,

    /// The declaration is referenced in a context that does not have an
    /// adequate minimum version constraint. For example, a reference to a
    /// declaration that is introduced in macOS 13 from a context that may
    /// execute on earlier versions of macOS has this constraint. This
    /// kind of constraint can be satisfied by tightening the minimum
    /// version of the context with `if #available(...)` or by adding or
    /// adjusting an `@available` attribute.
    IntroducedInNewerVersion,
  };

private:
  llvm::PointerIntPair<SemanticAvailableAttr, 2, Kind> attrAndKind;

  AvailabilityConstraint(Kind kind, SemanticAvailableAttr attr)
      : attrAndKind(attr, kind) {};

public:
  static AvailabilityConstraint
  forAlwaysUnavailable(SemanticAvailableAttr attr) {
    return AvailabilityConstraint(Kind::AlwaysUnavailable, attr);
  }

  static AvailabilityConstraint forObsoleted(SemanticAvailableAttr attr) {
    return AvailabilityConstraint(Kind::Obsoleted, attr);
  }

  static AvailabilityConstraint forRequiresVersion(SemanticAvailableAttr attr) {
    return AvailabilityConstraint(Kind::RequiresVersion, attr);
  }

  static AvailabilityConstraint
  forIntroducedInNewerVersion(SemanticAvailableAttr attr) {
    return AvailabilityConstraint(Kind::IntroducedInNewerVersion, attr);
  }

  Kind getKind() const { return attrAndKind.getInt(); }
  SemanticAvailableAttr getAttr() const {
    return static_cast<SemanticAvailableAttr>(attrAndKind.getPointer());
  }

  /// Returns the domain that the constraint applies to.
  AvailabilityDomain getDomain() const { return getAttr().getDomain(); }

  /// Returns the platform that this constraint applies to, or
  /// `PlatformKind::none` if it is not platform specific.
  PlatformKind getPlatform() const;

  /// Returns the required range for `IntroducedInNewerVersion` requirements, or
  /// `std::nullopt` otherwise.
  std::optional<AvailabilityRange>
  getRequiredNewerAvailabilityRange(ASTContext &ctx) const;

  /// Returns true if this unmet requirement can be satisfied by introducing an
  /// `if #available(...)` condition in source.
  bool isConditionallySatisfiable() const;

  /// Some availability constraints are active for type-checking but cannot
  /// be translated directly into an `if #available(...)` runtime query.
  bool isActiveForRuntimeQueries(ASTContext &ctx) const;
};

/// Represents a set of availability constraints that restrict use of a
/// declaration in a particular context.
class DeclAvailabilityConstraints {
  using Storage = llvm::SmallVector<AvailabilityConstraint, 4>;
  Storage constraints;

public:
  DeclAvailabilityConstraints() {}

  void addConstraint(const AvailabilityConstraint &constraint) {
    constraints.emplace_back(constraint);
  }

  using const_iterator = Storage::const_iterator;
  const_iterator begin() const { return constraints.begin(); }
  const_iterator end() const { return constraints.end(); }
};

/// Returns the `AvailabilityConstraint` that describes how \p attr restricts
/// use of \p decl in \p context or `std::nullopt` if there is no restriction.
std::optional<AvailabilityConstraint>
getAvailabilityConstraintForAttr(const Decl *decl,
                                 const SemanticAvailableAttr &attr,
                                 const AvailabilityContext &context);

/// Returns the set of availability constraints that restrict use of \p decl
/// when it is referenced from the given context. In other words, it is the
/// collection of of `@available` attributes with unsatisfied conditions.
DeclAvailabilityConstraints
getAvailabilityConstraintsForDecl(const Decl *decl,
                                  const AvailabilityContext &context);
} // end namespace swift

#endif
