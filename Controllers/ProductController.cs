using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Nhom5_Mypham.Models; 

namespace Nhom5_Mypham.Controllers
{
    public class ProductController : Controller
    {
        private QL_MyPham_CocoonEntities db = new QL_MyPham_CocoonEntities();

        // TRANG DANH SÁCH SẢN PHẨM
        public ActionResult Index(string search, string loaiDa, decimal? giaMin, decimal? giaMax, string sortOrder, decimal? giaTu)
        {
            var products = db.SANPHAMs.AsQueryable();

            if (!string.IsNullOrEmpty(search))
            {
                products = products.Where(s => s.TenSP.Contains(search));
                ViewBag.SearchTerm = search;
            }

            if (!string.IsNullOrEmpty(loaiDa))
            {
                products = products.Where(s => s.LoaiDa == loaiDa);
                ViewBag.CurrentLoaiDa = loaiDa;
            }

            if (giaMin.HasValue) products = products.Where(s => s.Gia >= giaMin.Value);
            if (giaMax.HasValue) products = products.Where(s => s.Gia <= giaMax.Value);

            if (giaTu.HasValue)
                products = products.Where(s => s.Gia >= giaTu.Value);

            ViewBag.GiaMin = giaMin;
            ViewBag.GiaMax = giaMax;
            ViewBag.GiaTu = giaTu;

            switch (sortOrder)
            {
                case "price_asc":
                    products = products.OrderBy(s => s.Gia);
                    break;
                case "price_desc": 
                    products = products.OrderByDescending(s => s.Gia);
                    break;
                default: 
                    products = products.OrderBy(s => s.TenSP);
                    break;
            }
            ViewBag.CurrentSort = sortOrder;

            return View("Category", products.ToList());
        }

        // LỌC SẢN PHẨM THEO LOẠI
        public ActionResult Category(string id)
        {
            if (string.IsNullOrEmpty(id))
            {
                return RedirectToAction("Index", "Home");
            }

            var listSP = db.SANPHAMs.Where(s => s.MaLoai == id).OrderBy(s => s.Gia).ToList();

            var loai = db.LOAISANPHAMs.Find(id);
            ViewBag.TenLoai = (loai != null) ? loai.TenLoai : "Danh sách sản phẩm";

            if (listSP.Count == 0)
            {
                ViewBag.ThongBao = "Không có sản phẩm nào thuộc loại này.";
            }

            return View(listSP);
        }

        // XEM CHI TIẾT SẢN PHẨM 
        public ActionResult Detail(string id)
        {
            if (string.IsNullOrEmpty(id))
            {
                return new HttpStatusCodeResult(System.Net.HttpStatusCode.BadRequest);
            }

            var sp = db.SANPHAMs.SingleOrDefault(s => s.MaSP == id);

            if (sp == null)
            {
                return HttpNotFound();
            }

            ViewBag.SanphamLienQuan = db.SANPHAMs.Where(s => s.MaLoai == sp.MaLoai && s.MaSP != sp.MaSP).Take(4).ToList();

            return View(sp);
        }

        // TÌM KIẾM SẢN PHẨM
        [HttpGet]
        public ActionResult Search(string keyword)
        {
            if (string.IsNullOrEmpty(keyword))
            {
                return RedirectToAction("Index", "Home");
            }

            var listSP = db.SANPHAMs.Where(s => s.TenSP.Contains(keyword)).OrderBy(s => s.TenSP).ToList();

            ViewBag.Keyword = keyword;
            ViewBag.ThongBao = "Tìm thấy " + listSP.Count + " kết quả.";

            return View("Category", listSP);
        }

        // 5. MENU DANH MỤC
        [ChildActionOnly]
        public ActionResult MenuLoai()
        {
            var listLoai = db.LOAISANPHAMs.OrderBy(l => l.TenLoai).ToList();
            return PartialView("_MenuLoai", listLoai);
        }
    }
}