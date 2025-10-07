/**
 * Disk Kapasitesi Veri Yükleyici
 * Sayfalama, cache ve lazy loading özellikleri ile
 */
class DiskCapacityLoader {
    constructor() {
        this.pageSize = 50;
        this.currentPage = 1;
        this.totalPages = 0;
        this.isLoading = false;
        this.cache = new Map(); // Basit hafıza cache'i
        this.cacheTimeout = 5 * 60 * 1000; // 5 dakika
    }

    /**
     * Sayfalı veri yükle
     */
    async loadData(locationName, startDate = null, endDate = null, page = 1) {
        // Cache anahtarı oluştur
        const cacheKey = `${locationName}-${startDate}-${endDate}-${page}`;
        
        // Önce cache'den bak
        const cachedData = this.getFromCache(cacheKey);
        if (cachedData) {
            console.log('Cache\'den veri döndü:', cacheKey);
            return cachedData;
        }

        // Loading göster
        this.showLoading(true);
        
        try {
            const params = new URLSearchParams({
                page: page.toString(),
                pageSize: this.pageSize.toString()
            });
            
            if (startDate) params.append('startDate', startDate);
            if (endDate) params.append('endDate', endDate);

            const response = await fetch(`/api/DiskCapacity/${locationName}?${params}`, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error(`API Hatası: ${response.status}`);
            }

            const data = await response.json();
            
            // Pagination bilgilerini header'dan al
            this.totalPages = parseInt(response.headers.get('X-Page-Count') || '0');
            this.currentPage = parseInt(response.headers.get('X-Current-Page') || '1');
            
            // Cache'e kaydet
            this.saveToCache(cacheKey, data);
            
            console.log(`Veri yüklendi: Sayfa ${page}, Toplam ${data.totalRecords} kayıt`);
            return data;
            
        } catch (error) {
            console.error('Veri yükleme hatası:', error);
            this.showError('Veri yüklenirken hata oluştu: ' + error.message);
            throw error;
        } finally {
            this.showLoading(false);
        }
    }

    /**
     * En son veriyi al (cache'li)
     */
    async loadLatestData(locationName) {
        const cacheKey = `latest-${locationName}`;
        
        // Cache'den bak
        const cachedData = this.getFromCache(cacheKey);
        if (cachedData) {
            console.log('En son veri cache\'den döndü');
            return cachedData;
        }

        try {
            const response = await fetch(`/api/DiskCapacity/${locationName}/latest`);
            
            if (!response.ok) {
                throw new Error(`API Hatası: ${response.status}`);
            }

            const data = await response.json();
            
            // Daha kısa cache süresi (2 dakika)
            this.saveToCache(cacheKey, data, 2 * 60 * 1000);
            
            return data;
            
        } catch (error) {
            console.error('En son veri hatası:', error);
            return null;
        }
    }

    /**
     * Daha fazla veri yükle (sayfa artır)
     */
    async loadMoreData(locationName, startDate = null, endDate = null) {
        if (this.isLoading || this.currentPage >= this.totalPages) {
            return null;
        }

        const nextPage = this.currentPage + 1;
        return await this.loadData(locationName, startDate, endDate, nextPage);
    }

    /**
     * Cache'den veri al
     */
    getFromCache(key) {
        const cached = this.cache.get(key);
        if (!cached) return null;

        // Zaman aşımı kontrolü
        if (Date.now() - cached.timestamp > cached.ttl) {
            this.cache.delete(key);
            return null;
        }

        return cached.data;
    }

    /**
     * Cache'e veri kaydet
     */
    saveToCache(key, data, ttl = null) {
        this.cache.set(key, {
            data: data,
            timestamp: Date.now(),
            ttl: ttl || this.cacheTimeout
        });

        // Cache boyutunu sınırla (100 item)
        if (this.cache.size > 100) {
            const firstKey = this.cache.keys().next().value;
            this.cache.delete(firstKey);
        }
    }

    /**
     * Cache'i temizle
     */
    clearCache() {
        this.cache.clear();
        console.log('Cache temizlendi');
    }

    /**
     * Loading durumu göster
     */
    showLoading(show) {
        this.isLoading = show;
        const loadingEl = document.getElementById('loading-indicator');
        if (loadingEl) {
            loadingEl.style.display = show ? 'block' : 'none';
        }
    }

    /**
     * Hata mesajı göster
     */
    showError(message) {
        const errorEl = document.getElementById('error-message');
        if (errorEl) {
            errorEl.textContent = message;
            errorEl.style.display = 'block';
            
            // 5 saniye sonra gizle
            setTimeout(() => {
                errorEl.style.display = 'none';
            }, 5000);
        } else {
            alert(message);
        }
    }
}

/**
 * Disk Kapasitesi Dashboard Yöneticisi
 */
class DiskCapacityDashboard {
    constructor() {
        this.loader = new DiskCapacityLoader();
        this.currentLocation = 'Cevahir';
        this.autoRefreshInterval = null;
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.loadInitialData();
        this.startAutoRefresh();
    }

    /**
     * Event listener'ları ayarla
     */
    setupEventListeners() {
        // Yenile butonu
        const refreshBtn = document.getElementById('refresh-btn');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => this.refreshData());
        }

        // Daha fazla yükle butonu
        const loadMoreBtn = document.getElementById('load-more-btn');
        if (loadMoreBtn) {
            loadMoreBtn.addEventListener('click', () => this.loadMoreData());
        }

        // Lokasyon değişimi
        const locationSelect = document.getElementById('location-select');
        if (locationSelect) {
            locationSelect.addEventListener('change', (e) => {
                this.currentLocation = e.target.value;
                this.loadInitialData();
            });
        }

        // Infinite scroll
        window.addEventListener('scroll', () => this.handleScroll());
    }

    /**
     * İlk veriyi yükle
     */
    async loadInitialData() {
        try {
            // En son veriyi al
            const latestData = await this.loader.loadLatestData(this.currentLocation);
            if (latestData) {
                this.displayLatestData(latestData);
            }

            // Geçmiş veriyi sayfalı olarak al
            const historicalData = await this.loader.loadData(this.currentLocation);
            if (historicalData) {
                this.displayHistoricalData(historicalData.data, true); // true = temizle ve yeni ekle
                this.updatePaginationInfo(historicalData);
            }

        } catch (error) {
            console.error('İlk veri yükleme hatası:', error);
        }
    }

    /**
     * Veriyi yenile (cache temizle)
     */
    async refreshData() {
        this.loader.clearCache();
        await this.loadInitialData();
    }

    /**
     * Daha fazla veri yükle
     */
    async loadMoreData() {
        try {
            const moreData = await this.loader.loadMoreData(this.currentLocation);
            if (moreData && moreData.data.length > 0) {
                this.displayHistoricalData(moreData.data, false); // false = mevcut verilere ekle
                this.updatePaginationInfo(moreData);
            }
        } catch (error) {
            console.error('Daha fazla veri yükleme hatası:', error);
        }
    }

    /**
     * En son veriyi göster
     */
    displayLatestData(data) {
        const container = document.getElementById('latest-data-container');
        if (!container) return;

        const statusClass = data.status.toLowerCase();
        
        container.innerHTML = `
            <div class="latest-disk-info ${statusClass}">
                <h3>${data.locationName} - Son Durum</h3>
                <div class="disk-stats">
                    <div class="stat">
                        <label>Kullanım:</label>
                        <span class="usage-percent">${data.usagePercentage.toFixed(1)}%</span>
                    </div>
                    <div class="stat">
                        <label>Boş Alan:</label>
                        <span>${data.freeSpace.toFixed(2)} GB</span>
                    </div>
                    <div class="stat">
                        <label>Kullanılan:</label>
                        <span>${data.usedSpace.toFixed(2)} GB</span>
                    </div>
                    <div class="stat">
                        <label>Toplam:</label>
                        <span>${data.totalSpace.toFixed(2)} GB</span>
                    </div>
                    <div class="stat">
                        <label>Son Kontrol:</label>
                        <span>${new Date(data.checkDate).toLocaleString('tr-TR')}</span>
                    </div>
                </div>
                <div class="status-indicator ${statusClass}">${data.status}</div>
            </div>
        `;
    }

    /**
     * Geçmiş veriyi göster
     */
    displayHistoricalData(data, clearFirst = false) {
        const container = document.getElementById('historical-data-container');
        if (!container) return;

        if (clearFirst) {
            container.innerHTML = '<h3>Geçmiş Veriler</h3>';
        }

        const table = container.querySelector('table') || this.createHistoricalTable(container);
        const tbody = table.querySelector('tbody');

        data.forEach(item => {
            const row = tbody.insertRow();
            row.innerHTML = `
                <td>${new Date(item.checkDate).toLocaleDateString('tr-TR')}</td>
                <td>${item.totalSpace.toFixed(2)} GB</td>
                <td>${item.freeSpace.toFixed(2)} GB</td>
                <td>${item.usedSpace.toFixed(2)} GB</td>
                <td class="usage-cell ${this.getUsageClass(item.usagePercentage)}">
                    ${item.usagePercentage.toFixed(1)}%
                </td>
            `;
        });
    }

    /**
     * Geçmiş veri tablosu oluştur
     */
    createHistoricalTable(container) {
        const table = document.createElement('table');
        table.className = 'historical-data-table';
        table.innerHTML = `
            <thead>
                <tr>
                    <th>Tarih</th>
                    <th>Toplam</th>
                    <th>Boş</th>
                    <th>Kullanılan</th>
                    <th>Kullanım %</th>
                </tr>
            </thead>
            <tbody></tbody>
        `;
        container.appendChild(table);
        return table;
    }

    /**
     * Kullanım yüzdesine göre CSS class
     */
    getUsageClass(percentage) {
        if (percentage >= 90) return 'critical';
        if (percentage >= 80) return 'warning';
        if (percentage >= 70) return 'caution';
        return 'ok';
    }

    /**
     * Pagination bilgilerini güncelle
     */
    updatePaginationInfo(data) {
        const infoEl = document.getElementById('pagination-info');
        if (infoEl) {
            infoEl.textContent = `Sayfa ${data.currentPage}/${data.totalPages} - Toplam ${data.totalRecords} kayıt`;
        }

        // Daha fazla yükle butonunu güncelle
        const loadMoreBtn = document.getElementById('load-more-btn');
        if (loadMoreBtn) {
            loadMoreBtn.style.display = data.hasNextPage ? 'block' : 'none';
        }
    }

    /**
     * Scroll ile infinite loading
     */
    handleScroll() {
        if ((window.innerHeight + window.scrollY) >= document.body.offsetHeight - 1000) {
            // Sayfa sonuna yaklaşıldığında daha fazla veri yükle
            this.loadMoreData();
        }
    }

    /**
     * Otomatik yenileme başlat
     */
    startAutoRefresh() {
        // Her 5 dakikada en son veriyi yenile
        this.autoRefreshInterval = setInterval(async () => {
            try {
                const latestData = await this.loader.loadLatestData(this.currentLocation);
                if (latestData) {
                    this.displayLatestData(latestData);
                }
            } catch (error) {
                console.error('Otomatik yenileme hatası:', error);
            }
        }, 5 * 60 * 1000); // 5 dakika
    }

    /**
     * Otomatik yenilemeyi durdur
     */
    stopAutoRefresh() {
        if (this.autoRefreshInterval) {
            clearInterval(this.autoRefreshInterval);
            this.autoRefreshInterval = null;
        }
    }
}

// Sayfa yüklendiğinde dashboard'u başlat
document.addEventListener('DOMContentLoaded', () => {
    window.diskCapacityDashboard = new DiskCapacityDashboard();
});

// Global fonksiyonlar
window.DiskCapacityLoader = DiskCapacityLoader;
window.DiskCapacityDashboard = DiskCapacityDashboard; 