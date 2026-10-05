#!/usr/bin/env bash
set -e

echo "Compilando y ejecutando suite de pruebas unitarias para Onest Lite..."

swiftc -parse-as-library -o /tmp/onest_test_runner \
  Onest/features/Core/Models/*.swift \
  Onest/features/Core/Security/*.swift \
  Onest/features/Core/Network/*.swift \
  Onest/features/Core/Services/*.swift \
  Onest/features/Core/Utils/*.swift \
  Onest/features/Auth/LoginViewModel.swift \
  Onest/features/Loans/LoansViewModel.swift \
  Onest/features/LoanApplication/LoanApplicationViewModel.swift \
  OnestTests/Mocks/TestMocks.swift \
  OnestTests/TestRunner.swift

/tmp/onest_test_runner
