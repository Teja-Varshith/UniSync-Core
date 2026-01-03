Here is the minimal JavaScript code to add smooth scrolling and theme toggle functionality:

```javascript
// Select elements that exist in HTML
const sections = document.querySelectorAll('section');
const header = document.querySelector('header');
const body = document.body;

// Smooth Scrolling Functionality
function scrollToElement(element) {
  element.scrollIntoView({ behavior: 'smooth' });
}

sections.forEach((section) => {
  section.addEventListener('click', () => {
    // Remove active class from all sections
    sections.forEach((s) => s.classList.remove('active'));
    
    // Add active class to the clicked section
    section.classList.add('active');
    
    // Scroll to the clicked section
    scrollToElement(section);
  });
});

// Theme Toggle Functionality
const themeToggle = document.createElement('button');
themeToggle.textContent = 'Switch Theme';
header.appendChild(themeToggle);

let isDarkTheme = localStorage.getItem('theme') === 'dark';

if (isDarkTheme) {
  body.classList.add('dark-theme');
}

themeToggle.addEventListener('click', () => {
  if (body.classList.contains('dark-theme')) {
    body.classList.remove('dark-theme');
    localStorage.setItem('theme', '');
  } else {
    body.classList.add('dark-theme');
    localStorage.setItem('theme', 'dark');
  }
});
```

This JavaScript code adds smooth scrolling functionality by selecting all `section` elements and attaching a click event listener to each one. When a section is clicked, it removes the active class from all sections, adds it to the clicked section, and scrolls to that section.

The theme toggle functionality creates a button in the header and adds an event listener to it. When the button is clicked, it toggles the dark theme on or off by adding or removing the `dark-theme` class from the `body` element. The current theme setting is stored in local storage so that it persists even after the page reloads.