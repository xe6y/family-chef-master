package dto

import "time"

type SysDictTypeRequest struct {
	ID   int64  `json:"id"`
	Name string `json:"name" binding:"required"`
	Code string `json:"code"`
	Sort int8   `json:"sort"`
}

type SysDictDataRequest struct {
	DictTypeCode string `json:"dictTypeCode" binding:"required"`
	Name         string `json:"name" binding:"required"`
	Value        string `json:"value" binding:"required"`
	Sort         int8   `json:"sort"`
	ValueEx1     string `json:"value_ex1"`
	ValueEx2     string `json:"value_ex2"`
}

type SysDictDataBatchRequest struct {
	Datas []SysDictDataRequest `json:"datas" binding:"required,dive"`
}

type SysDictTypeResponse struct {
	ID            int64     `json:"id"`
	Name          string    `json:"name"`
	Code          string    `json:"code"`
	Sort          int8      `json:"sort"`
	CreatedAt     time.Time `json:"createdAt"`
	UpdatedAt     time.Time `json:"updatedAt"`
	CreatedBy     int64     `json:"createdBy"`
	UpdatedBy     int64     `json:"updatedBy"`
	CreatedByName string    `json:"createdByName"`
	UpdatedByName string    `json:"updatedByName"`
}

type SysDictDataResponse struct {
	ID              int64     `json:"id"`
	SysDictTypeCode string    `json:"dictTypeCode"`
	Name            string    `json:"name"`
	Value           string    `json:"value"`
	ValueEx1        string    `json:"valueEx1"`
	ValueEx2        string    `json:"valueEx2"`
	Sort            int8      `json:"sort"`
	CreatedAt       time.Time `json:"createdAt"`
	UpdatedAt       time.Time `json:"updatedAt"`
	CreatedBy       int64     `json:"createdBy"`
	UpdatedBy       int64     `json:"updatedBy"`
	CreatedByName   string    `json:"createdByName"`
	UpdatedByName   string    `json:"updatedByName"`
}

type SysDictDataUpdateRequest struct {
	ID       int64  `json:"id" binding:"required"`
	Name     string `json:"name" binding:"required"`
	Value    string `json:"value" binding:"required"`
	Sort     int8   `json:"sort"`
	ValueEx1 string `json:"value_ex1"`
	ValueEx2 string `json:"value_ex2"`
}

type SysDictTypeUpdateRequest struct {
	ID   int64  `json:"id" binding:"required"`
	Name string `json:"name" binding:"required"`
	Code string `json:"code"`
	Sort int8   `json:"sort"`
}

type SysDictTypeDeleteRequest struct {
	ID int64 `json:"id" binding:"required"`
}

type SysDictDataDeleteRequest struct {
	ID int64 `json:"id" binding:"required"`
}

type SysDictTypeListRequest struct {
	Page     int    `json:"page" form:"page"`
	PageSize int    `json:"pageSize" form:"pageSize"`
	Keyword  string `json:"keyword" form:"keyword"`
}

type SysDictDataListRequest struct {
	Page         int    `json:"page" form:"page"`
	PageSize     int    `json:"pageSize" form:"pageSize"`
	DictTypeCode string `json:"dictTypeCode" form:"dictTypeCode" binding:"required"`
	Keyword      string `json:"keyword" form:"keyword"`
}

type SysDictTypeListResponse struct {
	List  []SysDictTypeResponse `json:"list"`
	Total int64                 `json:"total"`
	Page  int                   `json:"page"`
	Size  int                   `json:"size"`
}

type SysDictDataListResponse struct {
	List  []SysDictDataResponse `json:"list"`
	Total int64                 `json:"total"`
	Page  int                   `json:"page"`
	Size  int                   `json:"size"`
}

type SysDictTypeDetailResponse struct {
	Type  SysDictTypeResponse   `json:"type"`
	Datas []SysDictDataResponse `json:"datas"`
}
