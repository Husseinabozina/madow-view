(() => {
  const lightbox = document.querySelector('.lightbox');
  const lightboxImage = lightbox?.querySelector('img');
  const lightboxCaption = lightbox?.querySelector('p');
  const closeButton = lightbox?.querySelector('.lightbox-close');

  document.querySelectorAll('[data-lightbox]').forEach((card) => {
    card.addEventListener('click', () => {
      if (!lightbox || !lightboxImage || !lightboxCaption) return;
      lightboxImage.src = card.dataset.lightbox;
      lightboxImage.alt = card.querySelector('img')?.alt ?? card.dataset.title ?? '';
      lightboxCaption.textContent = card.dataset.title ?? '';
      lightbox.showModal();
    });
  });

  closeButton?.addEventListener('click', () => lightbox?.close());
  lightbox?.addEventListener('click', (event) => {
    if (event.target === lightbox) lightbox.close();
  });
  lightbox?.addEventListener('close', () => {
    if (lightboxImage) lightboxImage.removeAttribute('src');
  });

  const downloadLink = document.querySelector('.button-download');
  const pendingMessage = document.querySelector('#download-pending');
  if (downloadLink && pendingMessage) {
    fetch(downloadLink.href, { method: 'HEAD', cache: 'no-store' })
      .then((response) => {
        if (response.ok) {
          downloadLink.hidden = false;
          pendingMessage.hidden = true;
        }
      })
      .catch(() => {
        // Keep the download slot hidden when the demo APK has not been added yet.
      });
  }

  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const revealItems = document.querySelectorAll('.journey-card, .invitation-card, .screen-card');
  if (!reduceMotion && 'IntersectionObserver' in window) {
    revealItems.forEach((item) => item.classList.add('reveal'));
    const observer = new IntersectionObserver((entries, currentObserver) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          currentObserver.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12 });
    revealItems.forEach((item) => observer.observe(item));
  }
})();
