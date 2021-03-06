// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unit test for validation of modular steps in a pipeline.
import 'package:test/test.dart';
import 'package:modular_test/src/suite.dart';
import 'package:modular_test/src/pipeline.dart';

main() {
  test('no steps is OK', () {
    validateSteps([]);
  });

  test('no errors', () {
    var id1 = DataId("data_a");
    var id2 = DataId("data_b");
    var id3 = DataId("data_c");
    validateSteps([
      ModularStep(
          needsSources: true, dependencyDataNeeded: [id1], resultId: id1),
      ModularStep(moduleDataNeeded: [id1], resultId: id2),
      ModularStep(
          moduleDataNeeded: [id2],
          dependencyDataNeeded: [id1, id3],
          resultId: id3),
    ]);
  });

  test('circular dependency is not allowed', () {
    var id1 = DataId("data_a");
    expect(
        () => validateSteps([
              ModularStep(moduleDataNeeded: [id1], resultId: id1),
            ]),
        throwsA(TypeMatcher<InvalidPipelineError>()));
  });

  test('out of order dependencies are not allowed', () {
    var id1 = DataId("data_a");
    var id2 = DataId("data_b");
    validateSteps([
      ModularStep(resultId: id1), // id1 must be produced before it is consumed.
      ModularStep(dependencyDataNeeded: [id1], resultId: id2),
    ]);

    expect(
        () => validateSteps([
              ModularStep(dependencyDataNeeded: [id1], resultId: id2),
              ModularStep(resultId: id1),
            ]),
        throwsA(TypeMatcher<InvalidPipelineError>()));
  });

  test('same data cannot be produced by two steps', () {
    var id1 = DataId("data_a");
    expect(
        () => validateSteps([
              ModularStep(resultId: id1),
              ModularStep(resultId: id1),
            ]),
        throwsA(TypeMatcher<InvalidPipelineError>()));
  });
}

validateSteps(List<ModularStep> steps) {
  new _NoopPipeline(steps);
}

/// An implementation of [Pipeline] that simply validates the steps, but doesn't
/// do anything else.
class _NoopPipeline extends Pipeline {
  _NoopPipeline(List<ModularStep> steps) : super(steps);

  @override
  Future<void> runStep(ModularStep step, Module module,
          Map<Module, Set<DataId>> visibleData) =>
      null;
}
