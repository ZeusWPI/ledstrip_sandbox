export default class Utils{
    public static offerContentsAsDownloadableFile(contents: string | Blob, fileName: string = "download.txt",
                                                  options?: { mimetype: string }) {
        const element = document.createElement("a");
        let file;
        if (typeof (contents) === "string") {
            file = new Blob([contents], {type: options?.mimetype ?? 'text/plain'});
        } else {
            file = contents;
        }
        element.href = URL.createObjectURL(file);
        element.download = fileName;
        document.body.appendChild(element); // Required for this to work in FireFox
        element.click();
    }

}