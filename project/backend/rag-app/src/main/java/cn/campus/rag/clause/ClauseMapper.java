package cn.campus.rag.clause;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

/** 条款表的 Mapper，同样是空接口 + BaseMapper 白送 CRUD */
@Mapper
public interface ClauseMapper extends BaseMapper<Clause> {
}
