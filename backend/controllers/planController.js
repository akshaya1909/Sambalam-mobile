import asyncHandler from "../middleware/asyncHandler.js";
import Plan from "../models/planModel.js";
import Feature from "../models/featureModel.js";

// @desc    Get all plans
export const getPlans = asyncHandler(async (req, res) => {
    const plans = await Plan.find({}).sort({ price: 1 });
    res.json(plans);
});

// @desc    Create a new plan
export const createPlan = asyncHandler(async (req, res) => {
    const plan = new Plan(req.body);
    const createdPlan = await plan.save();
    res.status(201).json(createdPlan);
});

// @desc    Update a plan
export const updatePlan = asyncHandler(async (req, res) => {
    const plan = await Plan.findById(req.params.id);
    if (plan) {
        Object.assign(plan, req.body);
        const updatedPlan = await plan.save();
        res.json(updatedPlan);
    } else {
        res.status(404);
        throw new Error("Plan not found");
    }
});


// @desc    Delete a plan and clean up feature references
export const deletePlan = asyncHandler(async (req, res) => {
    const plan = await Plan.findById(req.params.id);

    if (plan) {
        const planId = plan._id;
        
        // 1. Remove this plan from any Feature mappings
        await Feature.updateMany(
            { enabledPlans: planId },
            { $pull: { enabledPlans: planId } }
        );

        // 2. Delete the plan
        await Plan.deleteOne({ _id: planId });
        
        res.json({ message: "Plan and associated feature links removed" });
    } else {
        res.status(404);
        throw new Error("Plan not found");
    }
});