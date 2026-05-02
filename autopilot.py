name: System-Pro-Auto-Pilot-Core

on:
  push:
    branches: [ main ]
  repository_dispatch:
    types: [build-app]
  workflow_dispatch:

permissions:
  contents: write

jobs:
  auto_pilot_job:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Run Faisal's Auto-Pilot
        run: |
          python3 autopilot.py

      - name: 🚀 Execute Build & Auto-Fix
        run: |
          # یہاں گریڈل 8.5 کا سیٹ اپ چلے گا
          chmod +x gradlew || gradle wrapper --gradle-version 8.5
          ./gradlew :app:assembleDebug --no-daemon
