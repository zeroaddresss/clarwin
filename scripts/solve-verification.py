#!/usr/bin/env python3
"""Solve Moltbook verification challenges (lobster math puzzles).

The challenges use obfuscated text with doubled letters, random caps,
and special chars. Numbers are spelled out. We de-obfuscate and use
fuzzy matching to extract numbers and determine the operation.
"""

import re
import sys

NUMBERS = {
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14,
    'fifteen': 15, 'sixteen': 16, 'seventeen': 17, 'eighteen': 18,
    'nineteen': 19, 'twenty': 20, 'thirty': 30, 'forty': 40,
    'fifty': 50, 'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90
}


def levenshtein(s1, s2):
    if len(s1) < len(s2):
        return levenshtein(s2, s1)
    if len(s2) == 0:
        return len(s1)
    prev = list(range(len(s2) + 1))
    for i, c1 in enumerate(s1):
        curr = [i + 1]
        for j, c2 in enumerate(s2):
            curr.append(min(prev[j + 1] + 1, curr[j] + 1, prev[j] + (c1 != c2)))
        prev = curr
    return prev[-1]


def deobfuscate(text):
    """Remove special chars, lowercase, and collapse consecutive duplicate chars."""
    text = re.sub(r'[^\w\s\'-]', '', text)
    text = text.lower()
    result = []
    for c in text:
        if not result or c != result[-1]:
            result.append(c)
    return ''.join(result)


def match_number_word(word):
    """Match a word to a number word using fuzzy matching. Returns (name, value, score) or None."""
    best = None
    best_score = 999.0
    for nw, nv in NUMBERS.items():
        d = levenshtein(word, nw)
        max_len = max(len(word), len(nw))
        rel_dist = d / max_len if max_len > 0 else 1.0
        # Require: absolute distance <= 2, AND relative distance <= 0.35
        # This prevents short-word false positives like "is" → "six"
        if d <= 2 and rel_dist <= 0.35:
            if rel_dist < best_score:
                best = (nw, nv, rel_dist)
                best_score = rel_dist
    return best


def find_numbers(text):
    """Extract numbers from de-obfuscated text using fuzzy matching."""
    words = re.split(r'[\s,]+', text)
    numbers = []
    i = 0
    while i < len(words):
        word = words[i].strip('-').strip("'")
        if not word or len(word) < 3:
            i += 1
            continue

        match = match_number_word(word)

        if match:
            nw, nv, _ = match
            # Check for compound number: "thirty two" → 32
            if i + 1 < len(words) and nv >= 20:
                next_word = words[i + 1].strip('-').strip("'")
                if next_word and len(next_word) >= 3:
                    next_match = None
                    next_score = 999.0
                    for nnw, nnv in NUMBERS.items():
                        if nnv < 10:
                            d = levenshtein(next_word, nnw)
                            max_len = max(len(next_word), len(nnw))
                            rel = d / max_len if max_len > 0 else 1.0
                            if d <= 2 and rel <= 0.35 and rel < next_score:
                                next_match = (nnw, nnv)
                                next_score = rel
                    if next_match:
                        numbers.append(nv + next_match[1])
                        i += 2
                        continue
            numbers.append(nv)
        i += 1
    return numbers


def determine_operation(text):
    """Determine the math operation from context words."""
    if any(w in text for w in ['total', 'sum', 'together', 'combined', 'add', 'plus', 'both']):
        return 'add'
    elif any(w in text for w in ['difference', 'subtract', 'minus', 'less', 'fewer', 'stronger']):
        return 'sub'
    elif any(w in text for w in ['product', 'multiply', 'times']):
        return 'mul'
    elif any(w in text for w in ['divide', 'quotient', 'ratio', 'per']):
        return 'div'
    return 'add'


def solve(challenge):
    """Solve a verification challenge, returning the numeric answer."""
    clean = deobfuscate(challenge)
    numbers = find_numbers(clean)
    op = determine_operation(clean)

    if not numbers:
        return None

    if op == 'add':
        return sum(numbers)
    elif op == 'sub' and len(numbers) >= 2:
        return numbers[0] - numbers[1]
    elif op == 'mul' and len(numbers) >= 2:
        result = 1
        for n in numbers:
            result *= n
        return result
    elif op == 'div' and len(numbers) >= 2 and numbers[1] != 0:
        return numbers[0] / numbers[1]
    return sum(numbers)


if __name__ == '__main__':
    challenge = sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read().strip()
    answer = solve(challenge)
    if answer is not None:
        print(f"{answer:.2f}")
    else:
        print("FAILED", file=sys.stderr)
        sys.exit(1)
