import express from "express";
import cors from "cors";
import { config } from "dotenv";

config({
  path: "./.env",
});

const app = express();
app.use(
  cors({
    origin: ["http://localhost:5173"],
    methods: ["GET", "POST", "PUT", "DELETE"],
  })
);

//home route
app.get("/", (req, res) => {
  res.send("Hello, World!");
});

app.get("/studentship/:id", async (req, res) => {
  const studentId = req.params.id;
  try {
    const du_response = await fetch(
      `https://academic.eis.du.ac.bd/en/studentship/${studentId}`,
      {
        method: "GET",
        mode: "no-cors",
      }
    );

    if (du_response.status !== 200) {
      return res
        .send({ message: `Failed to verify Student ID ${studentId}.` })
        .status(400);
    }

    console.log(await du_response.json());

    res
      .send({
        message: `Student ID ${studentId} verified successfully.`,
        data: await du_response.json(),
      })
      .status(200);
  } catch (error) {
    console.log(error);
    res.send({ message: "An error occurred during verification." }).status(500);
  }
});

app.listen(3000, () => {
  console.log("Server is running on http://localhost:3000");
});
