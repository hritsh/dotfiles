(async function() {
        while (!Spicetify.React || !Spicetify.ReactDOM) {
          await new Promise(resolve => setTimeout(resolve, 10));
        }
        var openDinDgenius = (() => {
  // src/app.tsx
  async function main() {
    var _a;
    while (!(Spicetify == null ? void 0 : Spicetify.showNotification)) {
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
    const button = document.createElement("button");
    button.innerText = "Open in Genius";
    button.style.marginLeft = "10px";
    button.onclick = openInGenius;
    (_a = document.querySelector(".player-controls__left")) == null ? void 0 : _a.append(button);
    Spicetify.showNotification("Extension loaded!");
    const songInfo = await getSongInfo();
    if (songInfo) {
      Spicetify.showNotification(`Now playing: ${songInfo.title} - ${songInfo.artist}`);
    } else {
      Spicetify.showNotification("No song is currently playing.");
    }
  }
  async function openInGenius() {
    const track = Spicetify.Player.data.item;
    Spicetify.showNotification("Searching Genius for lyrics...");
    if (!track) {
      Spicetify.showNotification("No track is currently playing.");
      return;
    }
    const songTitle = track.metadata.title;
    const artistName = track.metadata.artist_name;
    const geniusUrl = `https://genius.com/search?q=${encodeURIComponent(artistName + " " + songTitle)}`;
  }
  async function getSongInfo() {
    const track = Spicetify.Player.data.item;
    if (!track) {
      return null;
    }
    return {
      title: track.metadata.title,
      artist: track.metadata.artist_name
    };
  }
  var app_default = main;

  // ../../../../../../../../private/var/folders/lr/y2vd4t0x5nq8c3zk2hwxpg600000gn/T/spicetify-creator/index.jsx
  (async () => {
    await app_default();
  })();
})();

      })();