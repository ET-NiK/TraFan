#include <iostream>
#include <unistd.h>
#include <string>

#include "functions/functions.h" 
#include "functions/files.h" 

#include <jsoncpp/json/json.h>
//~ #include <boost/format.hpp>

Json::Value jroot_src;	// Инфо об IP с которых идут пакеты
Json::Value jroot_dst;	// Инфо об IP на которые идут пакеты

Json::StyledWriter writer;

int min_packets = 100;

// ---------------------------------------------------------------------

void write_json()
{
	// Обработка IP, у которых > 1000 пакетов

	Json::Value jwrite;
	
	if( jroot_src.size() > 0 ) {
        for( Json::ValueIterator itr = jroot_src.begin() ; itr != jroot_src.end() ; itr++ ) {
            if (jroot_src[itr.key().asString()][0].asInt() > min_packets) {
				jwrite[itr.key().asString()][0] = jroot_src[itr.key().asString()][0];
				jwrite[itr.key().asString()][1] = jroot_src[itr.key().asString()][1];
			}
        }
    }
    
    file_put_contents("data/analise_src.json", writer.write(jwrite));
    jwrite.clear();
    
    if( jroot_dst.size() > 0 ) {
        for( Json::ValueIterator itr = jroot_dst.begin() ; itr != jroot_dst.end() ; itr++ ) {
            if (jroot_dst[itr.key().asString()][0].asInt() > 1000) {
				jwrite[itr.key().asString()][0] = jroot_dst[itr.key().asString()][0];
				jwrite[itr.key().asString()][1] = jroot_dst[itr.key().asString()][1];
			}
        }
    }
	
	file_put_contents("data/analise_dst.json", writer.write(jwrite));
}

void add_uniq(Json::Value & json, Json::Value & jscom, std::string addr)
{
	int jsize = json.size();
	bool found = false;
	
	if (jscom[addr][0].asInt() < min_packets) {
		return;
	}
	
	for (int i = 0; i < jsize; i++) {
		if (json[i] == addr) {
			found = true;
		}
	}
	
	if (!found) {
		json[ json.size() ] = addr;
	}
}

// ---------------------------------------------------------------------

void run_trafan()
{
	char buff[256];
	std::vector<std::string> expl;
	std::vector<std::string> expl2;
	
	int i = 0;

	while (std::cin != NULL) {
		i ++;
		
		std::cin.getline(buff, 256, '\n');

		if (buff[0] == '\0') {
			continue;
		}
		
		expl = explode(" ", std::string(buff));
		
		// Удаление порта из источника
		//~ expl2 = explode(".", expl[2]);
		//~ if (expl2.size() == 5) {
			//~ expl[2] = str(boost::format("%s.%s.%s.%s") % expl2[0] % expl2[1] % expl2[2] % expl2[3]);
		//~ }

		// Удаляем последнее двоеточие
		expl[4] = expl[4].substr(0, expl[4].size()-1);
		
		// Источник
		jroot_src[expl[2]][0] = jroot_src[expl[2]][0].asInt() + 1;
		add_uniq(jroot_src[expl[2]][1], jroot_dst, expl[4]);
		
		// Целевой IP
		jroot_dst[expl[4]][0] = jroot_dst[expl[4]][0].asInt() + 1;
		add_uniq(jroot_dst[expl[4]][1], jroot_src, expl[2]);
		
		if (i >= 10000) {
			i = 0;
			write_json();
		}
	}

	if (i != 0) {
		write_json();
	}
}

// ---------------------------------------------------------------------

int main() 
{
	run_trafan();
} 
