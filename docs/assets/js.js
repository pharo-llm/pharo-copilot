document.addEventListener("DOMContentLoaded", () => {
  const toc = document.querySelector(".toc");
  if (!toc) return;

  const links = Array.from(toc.querySelectorAll("a[href^='#']"));
  const targets = links
    .map(link => document.getElementById(link.getAttribute("href").slice(1)))
    .filter(Boolean);

  /* -----------------------------------------
   * Smooth scrolling
   * ----------------------------------------- */
  links.forEach(link => {
    link.addEventListener("click", e => {
      e.preventDefault();
      const id = link.getAttribute("href").slice(1);
      const target = document.getElementById(id);
      if (!target) return;

      target.scrollIntoView({
        behavior: "smooth",
        block: "start"
      });

      history.pushState(null, "", `#${id}`);
    });
  });

  /* -----------------------------------------
   * Scroll spy (active heading)
   * ----------------------------------------- */
  const observer = new IntersectionObserver(
    entries => {
      entries.forEach(entry => {
        const id = entry.target.id;
        const link = toc.querySelector(`a[href="#${id}"]`);
        if (!link) return;

        if (entry.isIntersecting) {
          links.forEach(l => l.classList.remove("active"));
          link.classList.add("active");

          expandParents(link);
        }
      });
    },
    {
      rootMargin: "-30% 0px -60% 0px",
      threshold: 0
    }
  );

  targets.forEach(target => observer.observe(target));

  /* -----------------------------------------
   * Collapsible TOC sections
   * ----------------------------------------- */
  toc.querySelectorAll("li > ul").forEach(ul => {
    const parentLink = ul.parentElement.querySelector(":scope > a");
    if (!parentLink) return;

    ul.style.display = "none";
    parentLink.classList.add("collapsible");

    parentLink.addEventListener("click", e => {
      if (e.metaKey || e.ctrlKey) return;
      e.preventDefault();

      const open = ul.style.display === "block";
      ul.style.display = open ? "none" : "block";
      parentLink.classList.toggle("open", !open);
    });
  });

  /* -----------------------------------------
   * Helpers
   * ----------------------------------------- */
  function expandParents(link) {
    let el = link.closest("ul");
    while (el && el !== toc) {
      el.style.display = "block";
      const parent = el.parentElement?.querySelector(":scope > a");
      parent?.classList.add("open");
      el = el.parentElement?.closest("ul");
    }
  }
});
document.addEventListener("DOMContentLoaded", () => {
  const btn = document.getElementById("theme-toggle");
  if (!btn) return;

  const root = document.documentElement;

  const getPreferred = () =>
    window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light";

  const saved = localStorage.getItem("theme");
  const initial = saved || getPreferred();

  const setTheme = (theme) => {
    root.setAttribute("data-bs-theme", theme);
    btn.textContent = theme === "dark" ? "☀️" : "🌙";
    localStorage.setItem("theme", theme);
  };

  setTheme(initial);

  btn.addEventListener("click", () => {
    const current = root.getAttribute("data-bs-theme") || "light";
    setTheme(current === "dark" ? "light" : "dark");
  });
});
