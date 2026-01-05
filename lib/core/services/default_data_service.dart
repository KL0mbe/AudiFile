enum IsSkip { all, song, none }

class DefaultDataService {
  DefaultDataService({required this.fastForward, required this.rewind, required this.isSkip});

  int fastForward;
  int rewind;
  IsSkip isSkip;

  bool setIsSkip(bool isSong) {
    switch (isSkip) {
      case IsSkip.all:
        return true;
      case IsSkip.none:
        return false;
      case IsSkip.song when isSong:
        return true;
      case IsSkip.song:
        return false;
    }
  }

  DefaultDataService copy() => DefaultDataService.fromMap(toJson());

  factory DefaultDataService.fromMap(Map<String, Object?> map) {
    return DefaultDataService(
      fastForward: map["fast_forward"] as int,
      rewind: map["rewind"] as int,
      isSkip: IsSkip.values.byName(map["is_skip"] as String),
    );
  }

  Map<String, dynamic> toJson() => {"fast_forward": fastForward, "rewind": rewind, "is_skip": isSkip.name};
}
