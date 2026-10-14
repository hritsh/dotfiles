// @ts-check
// Local fixes for the TUI theme after Spotify's class renames.
// Lives in an extension because the marketplace drops the local user.css.
(function tuiFixes() {
    const ID = "tui-fixes-style";
    const CSS = `
/* "Playing on <device>" bar: theme turned it solid green and it covered the seek bar */
.main-nowPlayingBar-container > .main-nowPlayingBar-nowPlayingBar ~ div {
    background-color: transparent !important;
    background-image: none !important;
}
.main-nowPlayingBar-container > .main-nowPlayingBar-nowPlayingBar ~ div span,
.main-nowPlayingBar-container > .main-nowPlayingBar-nowPlayingBar ~ div button {
    color: var(--spice-accent-active) !important;
}
.main-nowPlayingBar-container > .main-nowPlayingBar-nowPlayingBar ~ div svg {
    fill: var(--spice-accent-active);
    --encore-icon-fill: var(--spice-accent-active) !important;
}
/* lift the seek bar above it while it is showing */
.main-nowPlayingBar-container:has(> .main-nowPlayingBar-nowPlayingBar ~ div) .playback-bar {
    translate: 0 -28px !important;
}
`;
    function inject() {
        if (document.getElementById(ID)) return;
        const style = document.createElement("style");
        style.id = ID;
        style.textContent = CSS;
        document.head.appendChild(style);
    }
    inject();
    // the marketplace re-injects theme CSS at runtime; keep ours last
    new MutationObserver(() => {
        const el = document.getElementById(ID);
        if (!el) inject();
        else if (el !== document.head.lastElementChild) document.head.appendChild(el);
    }).observe(document.head, { childList: true });
})();
