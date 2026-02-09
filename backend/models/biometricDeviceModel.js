import mongoose from 'mongoose';

const biometricDeviceSchema = new mongoose.Schema({
    company: { type: mongoose.Schema.Types.ObjectId, ref: 'Company' },
    deviceName: { type: String, required: true },
    serialNumber: { type: String, required: true, unique: true },
    location: {
      address: String,
      lat: Number,
      lng: Number,
    },

    // Branches where this device is valid. If empty, treat as "all branches".
    branches: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Branch',
      },
    ],
    // ...other metadata
  }, { timestamps: true });
  
  const BiometricDevice = mongoose.model('BiometricDevice', biometricDeviceSchema);
  export default BiometricDevice;
  