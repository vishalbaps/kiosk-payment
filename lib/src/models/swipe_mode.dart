enum SwipeMode { swipeMode, swipeDipTap, swipeDip, swipeTap, swipe }

extension SwipeModeExtension on SwipeMode {
  int get value {
    switch (this) {
      case SwipeMode.swipeMode:
        return 0;
      case SwipeMode.swipeDipTap:
        return 1;
      case SwipeMode.swipeDip:
        return 2;
      case SwipeMode.swipeTap:
        return 3;
      case SwipeMode.swipe:
        return 4;
    }
  }

  static SwipeMode fromString(String key) {
    switch (key) {
      case "swipeMode":
        return SwipeMode.swipeMode;
      case "swipeDipTap":
        return SwipeMode.swipeDipTap;
      case "swipeDip":
        return SwipeMode.swipeDip;
      case "swipeTap":
        return SwipeMode.swipeTap;
      case "swipe":
        return SwipeMode.swipe;
      default:
        throw ArgumentError("Invalid SwipeMode string: $key");
    }
  }
}
