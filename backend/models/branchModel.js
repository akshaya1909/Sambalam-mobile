import mongoose from 'mongoose';

const branchSchema = new mongoose.Schema(
  {
    company: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    address: {
      type: String,
      required: true,
    },
    radius: {
      type: Number,
      default: 100, // metres
    },
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [lng, lat]
        // required: true,
      },
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

// Geo index for location queries if needed
branchSchema.index({ location: '2dsphere' });

const Branch = mongoose.model('Branch', branchSchema);
export default Branch;
