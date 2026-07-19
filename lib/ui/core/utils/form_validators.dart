import 'package:flutter/material.dart';

class FormValidators {
  static FormFieldValidator<String> validateAmount() {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter an amount';
      }
      if (double.tryParse(value) == null || double.parse(value) <= 0) {
        return 'Please enter a valid amount';
      }
      return null;
    };
  }

  static FormFieldValidator<String> validateDescription() {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter a description';
      }
      return null;
    };
  }

  static FormFieldValidator<String> validatePersonName() {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter a person name';
      }
      return null;
    };
  }
}