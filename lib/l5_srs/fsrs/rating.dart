/// A review grade (spec §12's FSRS algorithm), matching the reference
/// `open-spaced-repetition/py-fsrs` implementation's `Rating` `IntEnum`
/// exactly (`Again=1, Hard=2, Good=3, Easy=4`) -- [value] is read directly
/// into `FsrsScheduler`'s ported formulas, several of which key off this
/// exact integer (e.g. `initialStability`'s `parameters[rating.value - 1]`),
/// so the ordering/values here must not drift from upstream.
enum Rating {
  again(1),
  hard(2),
  good(3),
  easy(4);

  const Rating(this.value);

  final int value;
}
