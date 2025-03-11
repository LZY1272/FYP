const app = require('./app');

const port = 8000;

app.get('/',(req,res)=>{
    res.send("Hello World!!!!!")
});

app.listen(port, () => {
    console.log(`Server Listening on Port http://localhost:${port}`);
});
