# Project structure

This project uses a two-folder structure to separate example code from working
code:

```
src/
├── components/     # Your working components (Storybook reads from here)
│   └── global.css  # Base styles imported by Storybook
├── stories/        # Your working stories (Storybook reads from here)
└── lib/            # Library utilities and mocks

examples/
├── components/     # Example component implementations (for reference)
└── stories/        # Example stories (for reference)
```
