# Exam Mode Firestore Schema

## Collection: `exam_subjects`

```json
{
  "title": "Compiler Design",
  "code": "CSEN3011",
  "description": "Compiler design overview",
  "semester": 5,
  "syllabusUnits": [
    "Introduction to Compilers",
    "Top Down Parsers",
    "Bottom Up Parsers"
  ],
  "pyqs": {
    "mid1_2024": "https://example.com/mid1.pdf",
    "sem_2023": "https://example.com/sem.pdf"
  },
  "cheatsheetUrl": "https://example.com/cheatsheet.pdf"
}
```

## Collection: `authors`

```json
{
  "name": "Author Name",
  "writtenSubjects": {
    "CSEN3011": "https://example.com/sample-important-questions.pdf",
    "CSEN4050": "https://example.com/sample-important-questions-2.pdf"
  }
}
```

## Notes

- the app filters `exam_subjects` only by `semester`.
- the `PYQs` tab reads the `pyqs` map and opens the PDF URL for each paper type.
- the `Cheatsheet` tab reads the single `cheatsheetUrl`.
- the `Important Questions` tab checks the `authors` collection and shows authors whose `writtenSubjects` map contains the current subject code.
- author-specific important question documents are not wired yet; you said you will provide that DB shape later.
