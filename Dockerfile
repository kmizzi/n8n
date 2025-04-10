FROM n8nio/n8n:latest

# Switch to root user to install packages and set up environment
USER root

# Install Cheerio & Luxon globally
RUN npm install -g cheerio luxon googleapis crypto-js

USER node