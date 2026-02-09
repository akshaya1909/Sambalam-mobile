import mongoose from 'mongoose';
import Note from '../models/notesModel.js';

// Get notes for a specific employee
export const getEmployeeNotes = async (req, res) => {
  try {
    const { employeeId } = req.params;
    const thread = await Note.findOne({ employeeId });
    
    // Return only the messages array or empty array if no thread exists
    res.status(200).json(thread ? thread.messages : []);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Post a new note (with optional file check)
export const createNote = async (req, res) => {
  try {
    const { employeeId, companyId, senderId, senderName, senderType, text } = req.body;

    if (!employeeId || !companyId) {
      return res.status(400).json({ message: "Employee ID and Company ID are required" });
    }

    let fileUrl = null;
    let fileType = null;

    if (req.file) {
      // We save the path relative to the server (e.g., /uploads/123-image.jpg)
      fileUrl = `/uploads/${req.file.filename}`; 
      fileType = req.file.mimetype;
    }
    
    const newMessage = {
      senderId,
      senderName,
      senderType,
      text: text || "",
      fileUrl,
      fileType,
      createdAt: new Date()
    };

    const thread = await Note.findOneAndUpdate(
      { employeeId, companyId },
      { 
        $push: { messages: newMessage } 
      },
      { new: true, upsert: true }
    );

    res.status(201).json(newMessage);
  } catch (err) {
    console.error("Server Error:", err);
    res.status(500).json({ message: err.message });
  }
};