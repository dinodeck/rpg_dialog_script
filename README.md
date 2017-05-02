This project is two things

- A parser for a conversation language
- A UI for running the parsed conversations

# Verifying the Parser

The parser has a set of unit like tests.
These are especially useful if you want to extend the language and not break it.

1. Navigate to ./dialog_runner/parse
2. Run ./run_tests.lua

You should then expect some test ouput and a final line of the type:

> Tests passed [19/19]

