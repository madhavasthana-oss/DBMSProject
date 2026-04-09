run(){
echo    "<<<    running . . .    >>>>"
mvn exec:java
}

echo    "<<< DBMS Project builder >>>"
echo    "                            "
read -p "-> recompile? input(y/n) :  " choice
if [ "$choice" = "y" ] || [ "$choice" = "Y" ] ; then
    echo "--> compiling . . . "
    mvn compile
fi
run