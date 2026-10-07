import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/utils/view_state.dart';
import 'package:youtube_saver/domain/use_cases/ui/get_play_queue/get_play_queue_usecase.dart';
import 'package:youtube_saver/features/player/player_view_model.dart';

import '../fakes/fake_video_repository.dart';

void main() {
  late FakeVideoRepository videos;

  setUp(() {
    videos = FakeVideoRepository()
      ..add('a', 'f')
      ..add('b', 'f')
      ..add('c', 'f')
      ..add('elsewhere', 'other');
  });

  Future<PlayerViewModel> create({String? start}) async {
    final vm = PlayerViewModel(
      bundle: PlayerBundle(folderId: 'f', startVideoId: start),
      getPlayQueue: GetPlayQueueUsecase(videos),
    );
    await pumpEventQueue();
    return vm;
  }

  test('loads the direct videos and starts at the chosen one', () async {
    final vm = await create(start: 'b');

    expect(vm.queue.value, isA<ViewStateLoaded>());
    expect(vm.current!.id, 'b');
    vm.dispose();
  });

  test('starts at the first video for "Play all"', () async {
    final vm = await create();

    expect(vm.current!.id, 'a');
    vm.dispose();
  });

  test('a load failure is an Error state', () async {
    videos.failWith = const StorageFailure('boom');

    final vm = await create();

    expect(vm.queue.value, isA<ViewStateError>());
    vm.dispose();
  });

  test('auto-advance moves to the next video when one ends', () async {
    final vm = await create();

    vm.onEnded('a');

    expect(vm.current!.id, 'b');
    expect(vm.finished.value, isFalse);
    vm.dispose();
  });

  test('the last video ending finishes the queue and stops', () async {
    final vm = await create(start: 'c');

    vm.onEnded('c');

    expect(vm.current!.id, 'c');
    expect(vm.finished.value, isTrue);
    vm.dispose();
  });

  test('with auto-advance off, an ended video does not advance', () async {
    final vm = await create();
    vm.toggleAutoAdvance();

    vm.onEnded('a');

    expect(vm.current!.id, 'a');
    expect(vm.finished.value, isFalse);
    vm.dispose();
  });

  test('an event for a video that is not current is ignored', () async {
    final vm = await create();

    vm.onEnded('b');
    vm.onUnplayable('c');

    expect(vm.current!.id, 'a');
    expect(vm.unplayable.value, isEmpty);
    vm.dispose();
  });

  test('an unplayable video is marked and skipped', () async {
    final vm = await create();

    vm.onUnplayable('a');

    expect(vm.unplayable.value, {'a'});
    expect(vm.current!.id, 'b');
    vm.dispose();
  });

  test('an unplayable video stays current when auto-advance is off', () async {
    final vm = await create();
    vm.toggleAutoAdvance();

    vm.onUnplayable('a');

    expect(vm.current!.id, 'a');
    expect(vm.unplayable.value, {'a'});
    vm.dispose();
  });

  test('auto-advance skips over videos already marked unplayable', () async {
    final vm = await create();
    vm.select(1);
    vm.onUnplayable('b'); // moves on to c
    vm.select(0);

    vm.onEnded('a');

    expect(vm.current!.id, 'c');
    vm.dispose();
  });

  test('the last video being unplayable finishes the queue', () async {
    final vm = await create(start: 'c');

    vm.onUnplayable('c');

    expect(vm.finished.value, isTrue);
    vm.dispose();
  });

  test(
    'next, previous and select stay within the queue and clear finished',
    () async {
      final vm = await create(start: 'c');
      vm.onEnded('c');

      vm.next(); // already last
      expect(vm.current!.id, 'c');

      vm.previous();
      expect(vm.current!.id, 'b');
      expect(vm.finished.value, isFalse);

      vm.select(99);
      expect(vm.current!.id, 'b');
      vm.dispose();
    },
  );

  test(
    'a load that finishes after dispose does not touch the notifiers',
    () async {
      final vm = PlayerViewModel(
        bundle: const PlayerBundle(folderId: 'f'),
        getPlayQueue: GetPlayQueueUsecase(videos),
      );
      vm.dispose();

      await pumpEventQueue(); // would throw if it wrote to a disposed notifier
    },
  );
}
