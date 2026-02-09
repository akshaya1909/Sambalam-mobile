import asyncHandler from "../middleware/asyncHandler.js";
import Addon from "../models/addonModel.js";

// @desc    Get all global addons
export const getAddons = asyncHandler(async (req, res) => {
    const addons = await Addon.find({});
    res.json(addons);
});


// @desc    Create a new addon
export const createAddon = asyncHandler(async (req, res) => {
    const { label, price, billingCycle, durationMonths } = req.body;
    
    const addonExists = await Addon.findOne({ label });
    if (addonExists) {
        res.status(400);
        throw new Error("An addon with this label already exists");
    }

    const addon = await Addon.create({
        label,
        price,
        billingCycle,
        durationMonths
    });

    res.status(201).json(addon);
});


// @desc    Update a specific addon
export const updateAddon = asyncHandler(async (req, res) => {
    const { label, price, billingCycle, durationMonths } = req.body;
    const addon = await Addon.findById(req.params.id);

    if (addon) {
        addon.label = label;
        addon.price = price;
        addon.billingCycle = billingCycle;
        addon.durationMonths = durationMonths;
        const updatedAddon = await addon.save();
        res.json(updatedAddon);
    } else {
        res.status(404);
        throw new Error("Addon not found");
    }
});


// @desc    Delete a specific addon
// @route   DELETE /api/addons/:id
export const deleteAddon = asyncHandler(async (req, res) => {
    const addon = await Addon.findById(req.params.id);

    if (addon) {
        await Addon.deleteOne({ _id: addon._id });
        res.json({ message: "Addon removed successfully" });
    } else {
        res.status(404);
        throw new Error("Addon not found");
    }
});