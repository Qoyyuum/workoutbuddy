# Testing Guide for Workout Buddy

This document describes the testing setup and CI/CD workflow for the Workout Buddy application.

## Test Coverage

The comprehensive test suite in `test/widget_test.dart` covers:

### 📦 Models
- **WorkoutBuddy** - Core buddy functionality (feeding, training, evolution, stat buffs)
- **FoodNutrition** - Food nutrition calculations and health impact
- **UserProfile** - User profile management and calorie calculations
- **FoodDiaryEntry** - Food diary serialization and database operations
- **StatBuff** - Temporary stat buff system with decay mechanics
- **WorkoutType** - Workout configurations and stat gains
- **StatType** - Stat type display and metadata

### 🔧 Services
- **CalorieCalculator** - BMR, TDEE, calorie goals, and macro calculations

### 🎨 Widgets
- App instantiation and smoke tests

## Running Tests Locally

### Run all tests
```bash
flutter test
```

### Run with coverage
```bash
flutter test --coverage
```

### Run specific test group
```bash
flutter test --name "CalorieCalculator"
flutter test --name "WorkoutBuddy"
flutter test --name "FoodNutrition"
```

### Run in verbose mode
```bash
flutter test --verbose
```

### View coverage report
```bash
# Install lcov (if not already installed)
# Ubuntu/Debian: sudo apt-get install lcov
# macOS: brew install lcov
# Windows: choco install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
# macOS: open coverage/html/index.html
# Linux: xdg-open coverage/html/index.html
# Windows: start coverage/html/index.html
```

## GitHub Actions CI/CD

The workflow at `.github/workflows/flutter_test.yml` automatically runs tests on every push and pull request to the `master` or `main` branch.

### What the CI Pipeline Does

1. ✅ **Setup Environment**
   - Checks out code
   - Installs Java 17 (required for Flutter)
   - Installs Flutter 3.24.0 (stable channel)
   - Creates mock `.env.local` file for testing

2. 📦 **Install Dependencies**
   - Runs `flutter pub get`
   - Verifies Flutter installation with `flutter doctor -v`

3. 🔍 **Code Analysis**
   - Runs `flutter analyze` to check code quality
   - Reports any linting issues or warnings

4. 🧪 **Run Tests**
   - Executes all tests with `flutter test --coverage`
   - Generates coverage report

5. 📊 **Upload Coverage** (Optional)
   - Uploads coverage to Codecov (if configured)
   - Only runs on pull requests

### Setting Up Codecov (Optional)

1. Visit [codecov.io](https://codecov.io/)
2. Sign in with GitHub
3. Add your repository
4. Copy the upload token
5. Go to your GitHub repository → Settings → Secrets and variables → Actions
6. Add a new secret named `CODECOV_TOKEN` with the token value

### Viewing CI Results

After pushing code or creating a pull request:

1. Go to the **Actions** tab in your GitHub repository
2. Click on the latest workflow run
3. View logs for each step
4. Check for any test failures or warnings

### Branch Protection (Recommended)

To enforce tests before merging:

1. Go to Settings → Branches → Branch protection rules
2. Add rule for `master` or `main` branch
3. Enable:
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - Select: `Run Flutter Tests`

## Test Structure

### Unit Tests
Focus on individual functions and methods:
```dart
test('description of what is being tested', () {
  // Arrange: Set up test data
  final model = MyModel(param: value);
  
  // Act: Perform the action
  final result = model.someMethod();
  
  // Assert: Verify the result
  expect(result, equals(expectedValue));
});
```

### Widget Tests
Test UI components (currently simplified to avoid platform dependencies):
```dart
testWidgets('description', (WidgetTester tester) async {
  // Build the widget
  await tester.pumpWidget(MyWidget());
  
  // Verify elements
  expect(find.text('Expected Text'), findsOneWidget);
});
```

## Writing New Tests

### Adding Tests for New Features

1. Add your test in the appropriate `group()` block
2. Follow the Arrange-Act-Assert pattern
3. Use descriptive test names
4. Test both success and failure cases

Example:
```dart
group('MyNewFeature', () {
  test('does something correctly', () {
    // Arrange
    final feature = MyNewFeature(param: value);
    
    // Act
    final result = feature.doSomething();
    
    // Assert
    expect(result, isTrue);
  });
  
  test('handles edge case', () {
    // Test edge cases...
  });
});
```

### Best Practices

- ✅ Test one thing per test
- ✅ Use descriptive test names
- ✅ Keep tests simple and readable
- ✅ Test edge cases and error conditions
- ✅ Mock external dependencies
- ✅ Avoid testing implementation details
- ✅ Run tests before committing

## Test Coverage Goals

- **Models**: 90%+ coverage (business logic)
- **Services**: 90%+ coverage (calculations)
- **Widgets**: Focus on critical user flows
- **Overall**: Aim for 80%+ coverage

## Troubleshooting

### Tests fail locally

1. Update Flutter: `flutter upgrade`
2. Clean project: `flutter clean && flutter pub get`
3. Check syntax: `flutter analyze`
4. Ensure `.env.local` file exists

### GitHub Actions fails

1. Check the workflow logs in the Actions tab
2. Verify Flutter version compatibility
3. Ensure all dependencies are in `pubspec.yaml`
4. Check if `.env.local` is properly mocked in workflow

### Coverage not generating

1. Run with coverage flag: `flutter test --coverage`
2. Check that `coverage/lcov.info` is created
3. Install lcov for local viewing
4. Ensure no syntax errors in tests

## Continuous Integration Status

Check the status of your latest builds:

- View in GitHub Actions tab
- Look for the green checkmark ✅ or red X ❌
- Click on the workflow run for detailed logs

## Future Improvements

Potential enhancements to the test suite:

- [ ] Add integration tests for full user workflows
- [ ] Add widget tests with proper mocking of platform channels
- [ ] Add performance benchmarks
- [ ] Add screenshot tests for UI consistency
- [ ] Increase coverage to 90%+
- [ ] Add mutation testing
- [ ] Set up automated performance testing

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Codecov Documentation](https://docs.codecov.com/)
