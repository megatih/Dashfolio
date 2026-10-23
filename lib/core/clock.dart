/// Injectable time source so calculations and refresh logic are testable.
abstract class Clock {
  const Clock();
  DateTime now();
}

class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

class FixedClock extends Clock {
  FixedClock(this.value);
  DateTime value;

  @override
  DateTime now() => value;
}

/// Date-only (midnight UTC) helper used for trade dates.
DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);
