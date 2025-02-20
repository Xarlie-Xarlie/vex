export default {
  mounted() {
    this.el.addEventListener("change", async (event) => {
      var file = event.target.files[0];
      file.completed = false;
      var offset = 0;
      if (file) {
        await this.streamFile(file, offset, event);
        offset = 0;
        event.target.removeEventListener("change", () => {});
      }
    });
  },

  async streamFile(file, offset, event) {
    const chunkSize = 256 * 1024;
    const sendNextChunk = async () => {
      if (file.completed) {
        return;
      }

      if (offset >= file.size && !file.completed) {
        this.pushEvent("upload_complete", { file_name: file.name });
        event.target.removeEventListener("change", () => {});
        file.completed = true;
        return;
      }

      const slice = file.slice(offset, offset + chunkSize);
      const arrayBuffer = await slice.arrayBuffer();
      const chunk = new Uint8Array(arrayBuffer);

      this.pushEvent("upload_chunk", {
        chunk: Array.from(chunk),
        file_name: file.name,
        chunks_qty: Math.round(file.size / chunkSize),
      });

      offset += chunkSize;
    };

    this.handleEvent("request_next_chunk", async () => {
      await sendNextChunk();
    });

    await sendNextChunk();
  },
};
