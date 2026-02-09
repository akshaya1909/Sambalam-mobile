import mongoose from "mongoose";

const announcementSchema = new mongoose.Schema({
  // Core content
  title: {
    type: String,
    required: [true, 'Title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  description: {
    type: String,
    required: [true, 'Description is required'],
    trim: true,
    maxlength: [5000, 'Description cannot exceed 5000 characters']
  },

  // Targeting
  targetBranches: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Branch',
    required: false // Optional if isAllBranches is true
  }],
  isAllBranches: {
    type: Boolean,
    default: true
  },

  // Metadata
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'AdminDetails', // Links to admin who created it
    required: true
  },
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true
  },

  // Status & Visibility
  status: {
    type: String,
    enum: ['draft', 'published', 'archived'],
    default: 'published'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isPinned: {
    type: Boolean,
    default: false
  },

  // Read tracking (optional)
  readBy: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    readAt: {
      type: Date,
      default: Date.now
    }
  }],

  // Stats
  totalViews: {
    type: Number,
    default: 0
  },
  totalReads: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Indexes for performance
announcementSchema.index({ companyId: 1, createdAt: -1 });
announcementSchema.index({ targetBranches: 1, createdAt: -1 });
announcementSchema.index({ status: 1, isActive: 1, createdAt: -1 });
announcementSchema.index({ isPinned: 1, createdAt: -1 });

// Virtual for populated company names (for frontend convenience)
announcementSchema.virtual('targetBranchNames', {
  ref: 'Branch',
  localField: 'targetBranches', // Correct field name
  foreignField: '_id'
});

// Populate virtuals when converting to JSON
announcementSchema.set('toJSON', { virtuals: true });
announcementSchema.set('toObject', { virtuals: true });

const Announcement = mongoose.model('Announcement', announcementSchema);

export default Announcement;
