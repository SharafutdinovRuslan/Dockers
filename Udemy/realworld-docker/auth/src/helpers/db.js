const mongoose = require('mongoose');
const { db } = require("../congiguration");

module.exports.connectDB = () => {
    mongoose.connect(db, {useNewUrlParser: true});

    return mongoose.connection;
};
