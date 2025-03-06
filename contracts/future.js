const express = require("express");
const app = express();
app.use(express.json());

let positions = []; // In-memory storage for positions
let marketPrice = 0; // Global market price (for liquidation check)

// 📌 Open a Futures Position
app.post("/openPosition", (req, res) => {
  const { user, positionType, amount, leverage, entryPrice } = req.body;

  if (!user || !positionType || !amount || !leverage || !entryPrice) {
    return res
      .status(400)
      .json({ success: false, message: "Missing required fields" });
  }

  const positionId = positions.length + 1;
  const margin = amount / leverage;

  const newPosition = {
    id: positionId,
    user,
    positionType, // "long" or "short"
    amount,
    leverage,
    entryPrice,
    margin,
    status: "open",
  };

  positions.push(newPosition);
  res.json({ success: true, position: newPosition });
});

// 📌 Close a Position
app.post("/closePosition", (req, res) => {
  const { user, positionId, exitPrice } = req.body;

  const position = positions.find(
    (pos) => pos.id === positionId && pos.user === user
  );

  if (!position) {
    return res
      .status(404)
      .json({ success: false, message: "Position not found" });
  }

  if (position.status !== "open") {
    return res
      .status(400)
      .json({ success: false, message: "Position already closed" });
  }

  let profitLoss = 0;
  if (position.positionType === "long") {
    profitLoss = (exitPrice - position.entryPrice) * position.amount;
  } else {
    profitLoss = (position.entryPrice - exitPrice) * position.amount;
  }

  position.status = "closed";
  position.exitPrice = exitPrice;
  position.profitLoss = profitLoss;

  res.json({ success: true, position });
});

// 📌 Get All Open Positions
app.get("/openPositions", (req, res) => {
  const openPositions = positions.filter((pos) => pos.status === "open");
  res.json({ success: true, positions: openPositions });
});

// 📌 Get Position Details
app.get("/position/:id", (req, res) => {
  const position = positions.find((pos) => pos.id === parseInt(req.params.id));

  if (!position) {
    return res
      .status(404)
      .json({ success: false, message: "Position not found" });
  }

  res.json({ success: true, position });
});

// 📌 Get All Positions of a User
app.get("/userPositions/:userId", (req, res) => {
  const userPositions = positions.filter(
    (pos) => pos.user === req.params.userId
  );
  res.json({ success: true, positions: userPositions });
});

// 📌 Check Liquidation Status
app.post("/checkLiquidation", (req, res) => {
  const { user, positionId, currentPrice } = req.body;

  const position = positions.find(
    (pos) => pos.id === positionId && pos.user === user
  );

  if (!position) {
    return res
      .status(404)
      .json({ success: false, message: "Position not found" });
  }

  const liquidationPrice =
    position.positionType === "long"
      ? position.entryPrice * (1 - 1 / position.leverage)
      : position.entryPrice * (1 + 1 / position.leverage);

  const isLiquidated =
    (position.positionType === "long" && currentPrice <= liquidationPrice) ||
    (position.positionType === "short" && currentPrice >= liquidationPrice);

  res.json({
    success: true,
    isLiquidated,
    liquidationPrice,
    message: isLiquidated ? "Position liquidated" : "Safe from liquidation",
  });
});

// 📌 Update Market Price (for checking liquidation)
app.post("/updateMarketPrice", (req, res) => {
  const { price } = req.body;
  if (!price)
    return res.status(400).json({ success: false, message: "Price required" });

  marketPrice = price;
  res.json({ success: true, marketPrice });
});

// Start Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
