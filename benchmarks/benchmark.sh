#!/bin/bash
# benchmark.sh — standard workload used in all TFM scenarios
# 1) sequential write of a 4GB file     3) random write of 10,000 small files
# 2) sequential read (caches dropped)   4) random read of those files
# Run inside the target container: bash /app/benchmark.sh

cd /app/descifrado 2>/dev/null || cd /app/test_dir 2>/dev/null || cd /app/nfs_test

echo "==============================================="
echo " Iniciando Pruebas de Rendimiento de Disco"
echo "==============================================="

echo -e "\n[1/4] Escribiendo fichero grande (4GB)..."
dd if=/dev/zero of=dummy_file bs=1M count=4000 status=progress conv=fdatasync

echo -e "\n[2/4] Borrando caché y leyendo el fichero grande ..."
sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
dd if=dummy_file of=/dev/null bs=1M status=progress

echo -e "\n[3/4] Escribiendo 10,000 ficheros pequeños ..."
mkdir -p prueba_ficheros && cd prueba_ficheros
time for i in {1..10000}; do
    dd if=/dev/zero of=file_$i bs=4k count=1 conv=fdatasync 2>/dev/null
done

echo -e "\n[4/4] Borrando caché y leyendo los ficheros en orden aleatorio ..."
sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
time for i in $(shuf -i 1-10000); do
    cat file_$i > /dev/null
done

cd ..
rm -rf dummy_file prueba_ficheros
echo "==============================================="
echo " Pruebas finalizadas."
echo "==============================================="
