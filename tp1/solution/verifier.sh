#!/usr/bin/env bash
# La commande unique. Elle doit renvoyer 0.
set -e

echo "--- format et lint ---"
ruff format --check .
ruff check .

echo "--- complexite ---"
radon cc -s -a inventaire kata_parking
xenon --max-absolute B --max-modules A --max-average A inventaire kata_parking

echo "--- tests et couverture ---"
pytest --cov=inventaire --cov=kata_parking --cov-branch --cov-report=term-missing

echo ""
echo "Tout est vert."
