import { Document } from "../models/document.js";
import fs from "fs/promises";
import extractTextFromPdf from "../services/pdfParser.js";

export const createDocumentController = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: "please upload a pdf file",
      });
    }
    console.log("this is user :", req.body);
    const baseUrl = `http://localhost:${process.env.PORT || 8000}`;
    const fileUrl = `${baseUrl}/uploads/documents/${req.file.filename}`;
    const document = await Document.create({
      UserId: req.body.userId,
      filepath: fileUrl,
      fileSize: req.file.size,
      status: "processing",
      slug :req.body.slug
    });
    // process PDF in background (in production,use a queue like blue)
    processPDF(document._id, req.file.path).catch((err) => {
      console.error(`PDF processing error`, err);
    });

    res.status(200).json({
      success: true,
      data: document,
      message: "Document uploaded successfully.processing in progress...",
    });
  } catch (error) {
    if (req.file) {
      await fs.unlink(req.file.path).catch(() => {});
    }
    console.log("error while uploading the pdf :", error);
    res.status(500).json({
      success: false,
      message: "error while uploading the file",
      error: error,
    });
  }
};
const processPDF = async (documentId, filePath) => {
  try {
    const { text } = await extractTextFromPdf(filePath);
    console.log("text at pdf processing :",text)
    // update document
    const documentUpdaed = await Document.findByIdAndUpdate(documentId, {
      extractedText: text,
      status: "ready",
    });
    await documentUpdaed.save();
    console.log(`document ${documentId} processed sucessfully`);
  } catch (error) {
    console.log("error while processing the pdf", error);
    await Document.findByIdAndUpdate(documentId, {
      status: "failed",
    });
  }
};

export const deleteDocumentController = async (req, res) => {
  try {
    const { documentId } = req.params;
    const document = await Document.findByIdAndDelete({ _id: documentId });

    if (!document) {
      return res.status(404).json({
        success: false,
        message: "documnet is not found",
      });
    }

    res.status(200).json({
      success: false,
      message: "document is deleted Successfully",
    });
  } catch (error) {
    console.log("error while deleting document :", error);
    res.status(400).json({
      success: false,
      message: "error while deleting the document",
      error: error,
    });
  }
};