class OnboardingState {
  static final Set<String> selectedInterestCodes = {};

  static void toggle(String? code) {
    if (code == null) return;

    if (selectedInterestCodes.contains(code)) {
      selectedInterestCodes.remove(code);
    } else {
      selectedInterestCodes.add(code);
    }
  }

  static List<String> get values {
    return selectedInterestCodes.toList();
  }

  static void clear() {
    selectedInterestCodes.clear();
  }
}
