generate: oklab/generate.py venv
	poetry run python -m oklab.generate

venv: .venv
	if [ ! -d ".venv" ]; then poetry install; fi
