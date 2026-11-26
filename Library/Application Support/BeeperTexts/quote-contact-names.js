// Run once per Beeper window session from its developer console.
// Reads the visible chat header and labels incoming quotes in direct chats.
(() => {
  const observerKey = Symbol.for("custom-css.quote-contact-names");
  window[observerKey]?.disconnect();

  const quoteSelector = ".is-dm .message-main > .LinkedMessage-module__linkedMessage";
  const labelAttribute = "data-custom-quote-author";

  function updateQuoteNames() {
    for (const conversation of document.querySelectorAll(".conversation")) {
      const name = conversation.querySelector(".thread-header-name")?.textContent.trim();
      for (const quote of conversation.querySelectorAll(quoteSelector)) {
        const content = Array.from(quote.querySelectorAll(".linked-message-content > .msg-text"));
        const target = name &&
          !quote.matches(".LinkedMessage-module__isSender, .LinkedMessage-module__unloadedMessage") &&
          !quote.querySelector(".linked-sender-name") &&
          (content.findLast(node => node.querySelector(".linked-message-inline-text")?.textContent.trim()) ||
            content.find(node => node.hasChildNodes()));

        for (const node of content) {
          if (node === target) {
            if (node.getAttribute(labelAttribute) !== name) node.setAttribute(labelAttribute, name);
          } else if (node.hasAttribute(labelAttribute)) {
            node.removeAttribute(labelAttribute);
          }
        }
      }
    }
  }

  let scheduled = false;
  const observer = new MutationObserver(() => {
    if (scheduled) return;
    scheduled = true;
    requestAnimationFrame(() => {
      scheduled = false;
      updateQuoteNames();
    });
  });
  observer.observe(document.body, { childList: true, subtree: true, characterData: true });
  window[observerKey] = observer;
  updateQuoteNames();
})();
