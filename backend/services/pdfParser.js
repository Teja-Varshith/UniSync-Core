import { PDFParse } from "pdf-parse";
const extractTextFromPdf = async (filepath) => {
  try {
    const data = new PDFParse({ url: filepath });
    const result = await data.getText();
    console.log("result at pdfparse :", result);
    return {
      text: result.text,
      numpages: result.pages,
      total: result.total,
    };
  } catch (error) {
    console.log(
      "error while extracting the text from the given document",
      error
    );
    throw new Error("Failed to extract text from pdf");
  }
};

export default extractTextFromPdf;