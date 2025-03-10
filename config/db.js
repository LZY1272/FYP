const mongoose = require('mongoose');

const connection = mongoose.createConnection('mongodb+srv://LZY1272:Ling_1272@cluster0.pqdov.mongodb.net/user').on('open',()=>{
    console.log("MongoDb Connected");
}).on('error',()=>{
    console.log("MongoDb connection error");
});

module.exports = connection;