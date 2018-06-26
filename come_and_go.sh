
END=4
for ((i=1;i<=END;i++)); do
	./migrate.sh $1
	./migrate2.sh $1
	sleep 1
done


