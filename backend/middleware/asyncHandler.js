// This is a Higher-order function
// fn- argument taken
// (req, res, next) -> returned function
const asyncHandler = fn => (req, res, next) => {
    Promise.resolve(fn(req, res, next).catch(next));
}

export default asyncHandler;