import 'package:flutter_test/flutter_test.dart';
import 'package:test_new_things/ui/core/utils/form_validators.dart';

void main() {
  group('FormValidators', () {
    group('validateAmount', () {
      test('returns error for empty string', () {
        expect(FormValidators.validateAmount()(''), 'Please enter an amount');
        expect(FormValidators.validateAmount()('   '), 'Please enter an amount');
      });

      test('returns error for non-numeric input', () {
        expect(FormValidators.validateAmount()('abc'), 'Please enter a valid amount');
        expect(FormValidators.validateAmount()('12.3.4'), 'Please enter a valid amount');
      });

      test('returns error for zero or negative numbers', () {
        expect(FormValidators.validateAmount()('0'), 'Please enter a valid amount');
        expect(FormValidators.validateAmount()('-5'), 'Please enter a valid amount');
      });

      test('returns null for valid positive amount', () {
        expect(FormValidators.validateAmount()('10'), null);
        expect(FormValidators.validateAmount()('10.50'), null);
        expect(FormValidators.validateAmount()('0.01'), null);
      });
    });

    group('validateDescription', () {
      test('returns error for empty string', () {
        expect(FormValidators.validateDescription()(''), 'Please enter a description');
        expect(FormValidators.validateDescription()('   '), 'Please enter a description');
      });

      test('returns null for non-empty string', () {
        expect(FormValidators.validateDescription()('Groceries'), null);
        expect(FormValidators.validateDescription()('  Rent  '), null);
      });
    });

    group('validatePersonName', () {
      test('returns error for empty string', () {
        expect(FormValidators.validatePersonName()(''), 'Please enter a person name');
        expect(FormValidators.validatePersonName()('   '), 'Please enter a person name');
      });

      test('returns null for non-empty string', () {
        expect(FormValidators.validatePersonName()('John'), null);
        expect(FormValidators.validatePersonName()('  Jane Doe  '), null);
      });
    });
  });
}
