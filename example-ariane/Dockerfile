# Use the official Node.js image as a base
FROM node:18

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy the package.json and package-lock.json files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy the application code into the container
COPY . .

# Expose the port on which the Express.js app runs
EXPOSE 3000

# Start the Express.js application
CMD ["node", "app.js"]
