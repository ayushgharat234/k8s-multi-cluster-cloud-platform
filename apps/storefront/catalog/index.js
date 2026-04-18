const express = require('express');
const { DynamoDBClient, ScanCommand } = require("@aws-sdk/client-dynamodb");
const app = express();
const port = 8080;

const client = new DynamoDBClient({ region: process.env.AWS_REGION || "us-east-1" });

app.get('/health', (req, res) => {
  res.json({ status: "healthy", cloud: "AWS" });
});

app.get('/catalog/items', async (req, res) => {
  // Demonstrating DynamoDB access via IRSA (IAM Roles for Service Accounts)
  const params = {
    TableName: process.env.DYNAMODB_TABLE || "opsnexus-catalog"
  };

  try {
    const data = await client.send(new ScanCommand(params));
    res.json({
      service: "catalog-service",
      identity_verified: true,
      items: data.Items || []
    });
  } catch (err) {
    res.status(500).json({ status: "error", message: err.message });
  }
});

app.listen(port, () => {
  console.log(`Catalog service listening at http://localhost:${port}`);
});
